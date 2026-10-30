-- Shipped ItemDB recipe identities must survive event capture -> raw logs ->
-- empirical baselines -> personal valuation. These are offline client fixtures.
local checks=0
local function check(v,m) assert(v,m);checks=checks+1 end
local function eq(a,b,m) check(a==b,(m or 'mismatch')..': '..tostring(a)..' ~= '..tostring(b)) end
local function copy(v) if type(v)~='table' then return v end local n={} for k,x in pairs(v) do n[k]=copy(x) end return n end
local now,frames,timers=0,{},{}
GetTime=function()return now end;time=function()return 2000000+now end
GetBuildInfo=function()return '12.1.5','123456','Oct 29 2026',120105 end
UnitName=function()return 'Tester'end;GetRealmName=function()return 'Realm'end
CreateFrame=function()
 local f={events={}};function f:RegisterEvent(e)self.events[e]=true end
 function f:SetScript(_,fn)self.fn=fn end;frames[#frames+1]=f;return f
end
C_Timer={After=function(delay,fn)timers[#timers+1]={at=now+delay,fn=fn}end}
local function emit(event,...)for _,f in ipairs(frames)do if f.events[event]then f.fn(f,event,...)end end end
local function advance(seconds)
 local finish=now+seconds
 while true do
  local index,first
  for i,t in ipairs(timers)do if t.at<=finish and (not first or t.at<first.at)then index,first=i,t end end
  if not first then break end
  table.remove(timers,index);now=first.at;first.fn()
 end
 now=finish
end
local LL={db={recordConversions=true,recordDisenchants=true,characters={},minPersonalSamples=1}}
for _,file in ipairs({'ItemDBRuntime.lua','ProfessionModels.lua','Database.lua','Professions.lua','Observations.lua',
 'CraftRecording.lua','ConversionEngine.lua'})do assert(loadfile('LootLiquidator/'..file))('LootLiquidator',LL)end
check(LL:InitializeItemDB());LL:MigrateEvidenceSettings()
LL.Invalidate=function(self)self._processingModelCache=nil;self._processingContextCache=nil end
LL.CaptureCraftContext=function(self,recipe,f,method)
 return {character=self:CharacterKey(),recipeID=recipe,method=method,profileKind='measured',simulated=false,
  profession=self:ProfessionForMethod(method),skillLineID=1234,baseSkill=70,bonusSkill=5,effectiveSkill=75,
  specialization='none',equipment={},observed=time(),fieldStatus={equipment='measured'}}
end
LL.GetOutputPrice=function()return 100 end
local facts={[153635]={id=153635,quality=1,link='item:153635'}}
local counts={}
LL.SnapshotCraftBags=function()
 local variants={}for id in pairs(counts)do variants[id]={['item:'..id]=true}end
 return {counts=copy(counts),facts=copy(facts),variants=variants}
end
local function start(guid,recipe)
 emit('UNIT_SPELLCAST_SENT','player','',guid,recipe);emit('UNIT_SPELLCAST_START','player',guid,recipe)
end
local function finish(guid,recipe,output,quantity,typed,refund)
 emit('UNIT_SPELLCAST_SUCCEEDED','player',guid,recipe)
 if typed then emit('TRADE_SKILL_ITEM_CRAFTED_RESULT',{itemID=output,quantity=quantity,
  itemGUID=guid..'-output',operationID=900,resourcesReturned=refund or {}})
 else emit('LOOT_CLOSED')end
 advance(1.3)
end
local cases={{152506,256218},{152507,256223},{152508,256221}}
-- Sources may be disabled while collecting new research. Recognition requires
-- no trade-skill UI; when a generic schematic exists it must not rename Mill.
for _,key in ipairs(LL.SourceOrder)do LL:SetEvidenceSource(key,false,0)end
for i,c in ipairs(cases)do
 local input,recipe=c[1],c[2]
 facts[input]={id=input,link='item:'..input,quality=1,classID=7,subClassID=9,expansionID=7}
 eq(LL:ResearchProcessingInput(input).batch,5,'old hint remains distinguishable from exact recipe')
 if i==2 then
  C_TradeSkillUI={GetRecipeInfo=function()return {learned=true}end,
   GetRecipeSchematic=function(id)return {recipeID=id,outputItemID=153635,reagentSlotSchematics={
    {dataSlotIndex=1,required=true,quantityRequired=20,reagents={{itemID=input}}}}}end}
 end
 LL:StartCraftStudy('shipped mass '..input);counts={[input]=20};start('mass-'..i,recipe)
 counts={[153635]=5};finish('mass-'..i,recipe,153635,5,i~=3)
 local d=LL.db.craftResearch;local r=d.records[#d.records]
 check(r~=nil,'mass milling should produce a complete raw record')
 eq(r.operationID,'mass-'..i);eq(r.method,'Mill');eq(r.recipeID,recipe)
 eq(r.outputCoverage,'complete');eq(r.inputs[1].quantity,20);eq(r.nominalInputs[1].quantity,20)
 eq(d.contexts[r.contextID].method,'Mill')
 LL:SetEvidenceSource('personal',true,100)
 local personal=assert(LL:GetRecordedProcessingEstimate(facts[input],'Mill',20,recipe))
 eq(personal.samples,1);eq(personal.inputCount,20);eq(personal.materials[1].expectedQuantity,5)
 local model=assert(LL:ResolveEvidenceModel(facts[input],{name='Mill',inputCount=20,recipeID=recipe},personal,2))
 eq(LL:ValueProcessingModel(model,0,true),25,'units priced once per original herb')
 eq(model.personalStats.total,1)
 eq(LL:GetRecordedProcessingEstimate(facts[input],'Mill',5,recipe),nil,'five-input estimate cannot reuse twenty-input logs')
 LL:SetEvidenceSource('personal',false,0)
end
-- Empty mass operations join the correct denominator only after confirmation.
local input,recipe=cases[3][1],cases[3][2]
counts={[input]=20};start('mass-empty',recipe);counts={};finish('mass-empty',recipe,nil,nil,false);advance(13)
local d=LL.db.craftResearch;local empty=d.records[#d.records]
eq(empty.outputCoverage,'unresolved');check(LL:ConfirmEmptyCraft())
local baseline=assert(LL:CraftBaseline(empty.studyID,empty.contextID,recipe))
eq(baseline.operations,2);eq(baseline.materials[1].chance,.5);eq(baseline.materials[1].expectedQuantity,2.5)
eq(baseline.materials[1].minQuantity,5);eq(baseline.materials[1].maxQuantity,5)
-- Reported refunds change net consumption, never the nominal twenty-herb batch.
for _,returned in ipairs({1,20})do
 LL:StartCraftStudy('mass refund '..returned);counts={[input]=20};start('refund-'..returned,recipe)
 counts={[input]=returned,[153635]=5}
 finish('refund-'..returned,recipe,153635,5,true,{{reagent={itemID=input},quantity=returned}})
 local r=d.records[#d.records]
 eq(r.operationID,'refund-'..returned);eq(r.inputs[1].quantity,20-returned);eq(r.nominalInputs[1].quantity,20)
 local b=assert(LL:CraftBaseline(r.studyID,r.contextID,recipe));eq(b.expectedInputsConsumed[1].expectedQuantity,20-returned)
 LL:SetEvidenceSource('personal',true,100)
 local personal=assert(LL:GetRecordedProcessingEstimate(facts[input],'Mill',20,recipe))
 local model=assert(LL:ResolveEvidenceModel(facts[input],{name='Mill',inputCount=20,recipeID=recipe},personal,2))
 eq(LL:ValueProcessingModel(model,0,true,facts[input]),(500+100*returned)/20)
 LL:SetEvidenceSource('personal',false,0)
end
-- A partial delta cannot be legitimized by the old five-input hint.
LL:StartCraftStudy('wrong batch');local before=#d.records
counts={[input]=20};start('wrong-batch',recipe);counts={[input]=15,[153635]=5}
finish('wrong-batch',recipe,153635,5,true);advance(13)
eq(#d.records,before);check(d.studies[d.activeStudy].censored)
check(d.diagnostics[#d.diagnostics].reason:find('recipe processing batch',1,true))
-- Exact ItemDB identities also apply to modern quality-specific prospecting.
local ore=210931;facts[ore]={id=ore,link='item:'..ore,quality=1,reagentQuality=2,classID=7,subClassID=7,expansionID=10}
LL:StartCraftStudy('ranked prospect');counts={[ore]=5};start('ranked',434018)
counts={[153635]=3};finish('ranked',434018,153635,3,true)
local ranked=d.records[#d.records];eq(ranked.operationID,'ranked');eq(ranked.method,'Prospect');eq(ranked.nominalInputs[1].quantity,5)
LL:StartCraftStudy('wrong input quality');before=#d.records;facts[ore].reagentQuality=3
counts={[ore]=5};start('wrong-rank',434018);counts={[153635]=3};finish('wrong-rank',434018,153635,3,true);advance(13)
eq(#d.records,before);check(d.studies[d.activeStudy].censored)
-- The same herb can have separate five- and twenty-input recipe identities.
local original
for _,r in ipairs(LL.ItemDB.processing)do if r.inputItemID==input and r.recipeID==recipe then original=r;break end end
local alternate=copy(assert(original));alternate.recordID='synthetic-alternate-recipe';alternate.recipeID=900002;alternate.inputCount=5
alternate.materials={copy(alternate.materials[1])};alternate.materials[1].id=999001
LL.ItemDB.processing[#LL.ItemDB.processing+1]=alternate;check(LL:InitializeItemDB())
facts[999001]={id=999001,link='item:999001',quality=1}
LL:StartCraftStudy('alternate recipe');counts={[input]=5};start('alternate',900002)
counts={[999001]=2};finish('alternate',900002,999001,2,false)
local alt=d.records[#d.records];eq(alt.operationID,'alternate');eq(alt.method,'Mill');eq(alt.nominalInputs[1].quantity,5)
LL:StartCraftStudy('wrong recipe output');before=#d.records;counts={[input]=20};start('other-recipe-output',recipe)
counts={[999001]=2};finish('other-recipe-output',recipe,999001,2,false);advance(13)
eq(#d.records,before);eq(d.diagnostics[#d.diagnostics].reason,'Unmapped or unrelated output')
-- Conflicting recipe batches must not choose the one matching bag consumption.
local conflict=copy(original);conflict.recordID='synthetic-conflicting-batch';conflict.inputCount=5
LL.ItemDB.processing[#LL.ItemDB.processing+1]=conflict;check(LL:InitializeItemDB())
LL:StartCraftStudy('ambiguous batch');before=#d.records;counts={[input]=20};start('ambiguous',recipe)
counts={[153635]=5};finish('ambiguous',recipe,153635,5,true);advance(13)
eq(#d.records,before);check(d.studies[d.activeStudy].censored)
-- Reinitialization clears stale recipe entries after replacing a database.
LL.ItemDB.processing={};check(LL:InitializeItemDB());eq(LL:ResearchProcessingRecipeOperations(recipe),nil)
print('PASS: '..checks..' ItemDB recorder operation checks (real mass recipes, typed/bag outputs, zeros, pricing, source independence, quality and conflict gates)')
